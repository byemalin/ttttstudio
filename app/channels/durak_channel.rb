class DurakChannel < ApplicationCable::Channel
  SUITS = %w[♣ ♦ ♥ ♠].freeze
  RANKS = %w[6 7 8 9 10 J Q K A].freeze
  HAND_TARGET = 6

  class << self
    def games
      @games ||= {}
    end
  end

  def subscribed
    @game_id = params["game_id"].to_s.strip
    @player_id = params["player_id"].to_s.strip

    if @game_id.blank? || @player_id.blank?
      reject
      return
    end

    stream_from(stream_name(@game_id))
    stream_from(private_stream(@game_id, @player_id))
    transmit(type: "info", message: "Connected to table #{@game_id}.")
  end

  def unsubscribed
    return if @game_id.blank? || @player_id.blank?

    game = self.class.games[@game_id]
    return unless game

    player = find_player(game, @player_id)
    return unless player

    log_event(game, "#{player[:name]} left the table.")
    remove_player(@game_id, @player_id)
    broadcast_state(@game_id)
  end

  def receive(data)
    game_id = params["game_id"].presence
    player_id = data["playerId"].presence || params["player_id"].presence
    action = data["action"].presence

    return unless game_id && player_id && action

    case action
    when "join"
      handle_join(game_id, player_id, data)
    when "start"
      handle_start(game_id, player_id)
    when "attack"
      handle_attack(game_id, player_id, data)
    when "defend"
      handle_defend(game_id, player_id, data)
    when "pickup"
      handle_pickup(game_id, player_id)
    when "end_turn"
      handle_end_turn(game_id, player_id)
    else
      send_error(game_id, player_id, "Unknown action: #{action}")
    end
  rescue StandardError => e
    send_error(game_id, player_id, e.message)
  end

  private

  def handle_join(game_id, player_id, data)
    game = self.class.games[game_id] ||= new_game
    name = data["name"].presence || "Player"

    player = find_player(game, player_id)
    if player
      player[:name] = name
      player[:connected] = true
    else
      player = { id: player_id, name:, hand: [], connected: true }
      game[:players] << player
    end

    game[:message] = nil
    log_event(game, "#{player[:name]} joined the table.")

    broadcast_state(game_id)
  end

  def handle_start(game_id, player_id)
    game = fetch_game!(game_id)
    ensure_player_present!(game, player_id)

    if game[:players].length < 2
      send_error(game_id, player_id, "At least two players are required to start.")
      return
    end

    game[:deck] = build_deck.shuffle
    game[:discard] = []
    game[:table] = []
    game[:log] = [] if game[:log].blank?
    game[:message] = nil

    game[:trump_card] = game[:deck].last
    game[:status] = "playing"

    game[:players].each { |p| p[:hand] = [] }

    game[:attacker] = game[:players].first[:id]
    game[:defender] = next_player_id(game, game[:attacker])

    refill_hands(game, rotation_from(game, game[:attacker]))

    log_event(game, "#{player_name(game, player_id)} started a new game. Trump suit is #{game[:trump_card]["suit"]}.")
    broadcast_state(game_id)
  end

  def handle_attack(game_id, player_id, data)
    game = fetch_game!(game_id)

    unless game[:status] == "playing"
      send_error(game_id, player_id, "The game is not running.")
      return
    end

    unless game[:attacker] == player_id
      send_error(game_id, player_id, "Only the attacker can play an attack card.")
      return
    end

    card = normalize_card(data["card"])
    unless card
      send_error(game_id, player_id, "Invalid card data.")
      return
    end

    player = ensure_player_present!(game, player_id)

    unless remove_card_from_hand(player, card)
      send_error(game_id, player_id, "That card is not in your hand.")
      return
    end

    if game[:table].length >= maximum_attacks(game)
      player[:hand] << card
      send_error(game_id, player_id, "You cannot attack with more cards right now.")
      return
    end

    unless valid_attack_card?(game, card)
      player[:hand] << card
      send_error(game_id, player_id, "Attack card must match a rank already on the table.")
      return
    end

    game[:table] << { "attack" => card, "defense" => nil }
    log_event(game, "#{player[:name]} attacks with #{label_card(card)}.")

    broadcast_state(game_id)
  end

  def handle_defend(game_id, player_id, data)
    game = fetch_game!(game_id)

    unless game[:status] == "playing"
      send_error(game_id, player_id, "The game is not running.")
      return
    end

    unless game[:defender] == player_id
      send_error(game_id, player_id, "Only the defender can cover attack cards.")
      return
    end

    pair_index = data["pairIndex"].to_i
    pair = game[:table][pair_index]
    unless pair && pair["defense"].nil?
      send_error(game_id, player_id, "That attack is already defended.")
      return
    end

    card = normalize_card(data["card"])
    unless card
      send_error(game_id, player_id, "Invalid card data.")
      return
    end

    player = ensure_player_present!(game, player_id)

    unless remove_card_from_hand(player, card)
      send_error(game_id, player_id, "That card is not in your hand.")
      return
    end

    unless beats_card?(card, pair["attack"], game[:trump_card]["suit"])
      player[:hand] << card
      send_error(game_id, player_id, "That card cannot cover the attack.")
      return
    end

    pair["defense"] = card
    log_event(game, "#{player[:name]} defends with #{label_card(card)}.")

    broadcast_state(game_id)
  end

  def handle_pickup(game_id, player_id)
    game = fetch_game!(game_id)

    unless game[:status] == "playing"
      send_error(game_id, player_id, "The game is not running.")
      return
    end

    unless game[:defender] == player_id
      send_error(game_id, player_id, "Only the defender can pick up the cards.")
      return
    end

    if game[:table].empty?
      send_error(game_id, player_id, "There are no cards to pick up.")
      return
    end

    defender = ensure_player_present!(game, player_id)
    cards = game[:table].flat_map { |pair| [pair["attack"], pair["defense"]] }.compact
    defender[:hand].concat(cards)
    game[:table] = []

    next_defender = next_player_id(game, game[:defender])
    log_event(game, "#{defender[:name]} picks up the cards.")

    refill_hands(game, pickup_refill_order(game, defender[:id]))

    game[:defender] = next_defender

    broadcast_state(game_id)
  end

  def handle_end_turn(game_id, player_id)
    game = fetch_game!(game_id)

    unless game[:status] == "playing"
      send_error(game_id, player_id, "The game is not running.")
      return
    end

    unless game[:attacker] == player_id
      send_error(game_id, player_id, "Only the attacker can end the turn.")
      return
    end

    if game[:table].empty?
      send_error(game_id, player_id, "You must attack before ending the turn.")
      return
    end

    unless game[:table].all? { |pair| pair["defense"].present? }
      send_error(game_id, player_id, "All attacks must be defended before ending the turn.")
      return
    end

    attacker_name = player_name(game, player_id)
    defender_name = player_name(game, game[:defender])

    game[:discard].concat(game[:table].flat_map { |pair| [pair["attack"], pair["defense"]] })
    game[:table] = []

    game[:attacker] = game[:defender]
    game[:defender] = next_player_id(game, game[:attacker])

    refill_hands(game, rotation_from(game, game[:attacker]))

    log_event(game, "#{attacker_name} ends the attack. #{defender_name} takes the initiative.")

    check_for_finish(game)
    broadcast_state(game_id)
  end

  def build_deck
    SUITS.flat_map do |suit|
      RANKS.map { |rank| { "rank" => rank, "suit" => suit, "code" => "#{rank}#{suit}" } }
    end
  end

  def new_game
    {
      players: [],
      deck: [],
      discard: [],
      table: [],
      status: "waiting",
      attacker: nil,
      defender: nil,
      trump_card: nil,
      message: nil,
      log: []
    }
  end

  def fetch_game!(game_id)
    game = self.class.games[game_id]
    raise "Game not found." unless game

    game
  end

  def ensure_player_present!(game, player_id)
    player = find_player(game, player_id)
    raise "Player not found." unless player

    player
  end

  def find_player(game, player_id)
    game[:players].find { |p| p[:id] == player_id }
  end

  def remove_player(game_id, player_id)
    game = self.class.games[game_id]
    return unless game

    player = find_player(game, player_id)
    return unless player

    game[:players].delete(player)

    if game[:players].empty?
      self.class.games.delete(game_id)
      return
    end

    if %i[attacker defender].any? { |key| game[key] == player_id }
      game[:status] = "waiting"
      game[:attacker] = nil
      game[:defender] = nil
      game[:table] = []
      game[:message] = "A player left mid-hand. Waiting to start a new game."
    end
  end

  def rotation_from(game, starting_player_id)
    ids = game[:players].map { |p| p[:id] }
    return ids if starting_player_id.blank? || !ids.include?(starting_player_id)

    index = ids.index(starting_player_id)
    ids.rotate(index)
  end

  def pickup_refill_order(game, defender_id)
    order = rotation_from(game, game[:attacker])
    order.delete(defender_id)
    order << defender_id
    order
  end

  def refill_hands(game, order)
    return if game[:deck].blank?

    Array(order).each do |player_id|
      player = find_player(game, player_id)
      next unless player

      while player[:hand].length < HAND_TARGET && game[:deck].any?
        player[:hand] << game[:deck].shift
      end
    end
  end

  def maximum_attacks(game)
    defender = find_player(game, game[:defender])
    return HAND_TARGET unless defender

    [HAND_TARGET, defender[:hand].length].min
  end

  def valid_attack_card?(game, card)
    return true if game[:table].empty?

    ranks_in_play = game[:table].flat_map do |pair|
      [pair["attack"], pair["defense"]].compact.map { |c| c["rank"] }
    end

    ranks_in_play.include?(card["rank"])
  end

  def beats_card?(candidate, attack_card, trump_suit)
    return false unless candidate && attack_card

    if candidate["suit"] == attack_card["suit"]
      rank_index(candidate) > rank_index(attack_card)
    elsif candidate["suit"] == trump_suit && attack_card["suit"] != trump_suit
      true
    else
      false
    end
  end

  def rank_index(card)
    RANKS.index(card["rank"]) || -1
  end

  def normalize_card(card_hash)
    return unless card_hash
    rank = card_hash["rank"] || card_hash[:rank]
    suit = card_hash["suit"] || card_hash[:suit]
    code = card_hash["code"] || card_hash[:code] || "#{rank}#{suit}"

    return if rank.blank? || suit.blank?

    { "rank" => rank, "suit" => suit, "code" => code }
  end

  def remove_card_from_hand(player, card)
    index = player[:hand].find_index { |c| c["code"] == card["code"] }
    index ||= player[:hand].find_index { |c| c["rank"] == card["rank"] && c["suit"] == card["suit"] }
    return unless index

    player[:hand].delete_at(index)
  end

  def player_name(game, player_id)
    player = find_player(game, player_id)
    player ? player[:name] : "Player"
  end

  def send_error(game_id, player_id, message)
    ActionCable.server.broadcast(private_stream(game_id, player_id), { type: "error", message })
  end

  def log_event(game, message)
    return if message.blank?

    game[:log] ||= []
    timestamp = Time.current.strftime("%H:%M")
    entry = "[#{timestamp}] #{message}"
    game[:log] << entry
    game[:log] = game[:log].last(50)
    game[:message] = message
  end

  def broadcast_state(game_id)
    game = self.class.games[game_id]
    return unless game

    payload = {
      type: "state",
      state: {
        game_id: game_id,
        status: game[:status],
        attacker: game[:attacker],
        defender: game[:defender],
        players: game[:players].map { |player| { id: player[:id], name: player[:name], handCount: player[:hand].length } },
        table: game[:table].map { |pair| { attack: pair["attack"], defense: pair["defense"] } },
        trump_card: game[:trump_card],
        deck_count: game[:deck].length,
        discard_count: game[:discard].length,
        message: game[:message],
        log: game[:log]
      }
    }

    ActionCable.server.broadcast(stream_name(game_id), payload)
    broadcast_hands(game_id, game)
  end

  def broadcast_hands(game_id, game)
    game[:players].each do |player|
      ActionCable.server.broadcast(private_stream(game_id, player[:id]), { type: "hand", hand: player[:hand] })
    end
  end

  def stream_name(game_id)
    "durak_#{game_id}"
  end

  def private_stream(game_id, player_id)
    "durak_#{game_id}_#{player_id}"
  end

  def next_player_id(game, current_player_id)
    order = rotation_from(game, current_player_id)
    return nil if order.length < 2

    order[1]
  end

  def check_for_finish(game)
    return unless game[:status] == "playing"
    return unless game[:deck].empty? && game[:table].empty?

    active_players = game[:players].select { |player| player[:hand].any? }

    if active_players.empty?
      log_event(game, "Everyone cleared their hand. It's a draw!")
      game[:status] = "finished"
      game[:attacker] = nil
      game[:defender] = nil
    elsif active_players.length == 1
      loser = active_players.first
      log_event(game, "#{loser[:name]} is the durak!")
      game[:status] = "finished"
      game[:attacker] = nil
      game[:defender] = nil
    end
  end
end
