import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

// Stimulus controller powering the Durak experience.
export default class extends Controller {
  static targets = [
    "gameId",
    "name",
    "status",
    "players",
    "playersList",
    "table",
    "tablePairs",
    "hand",
    "handCards",
    "log",
    "trump",
    "deckCount",
    "discardCount",
    "controls",
    "startButton",
    "pickupButton",
    "endTurnButton"
  ]

  static values = {
    playerId: String
  }

  connect () {
    this.playerIdValue = this.generateId()
    this.consumer = null
    this.subscription = null
    this.state = null
    this.handState = []
    this.gameId = null
    this.playerName = null
    this.localLog = []
    this.statusTarget.textContent = "Enter a game ID and name to get started."
  }

  disconnect () {
    this.unsubscribe()
  }

  connectToGame (event) {
    if (event) event.preventDefault()

    const gameId = this.gameIdTarget?.value?.trim()
    const name = this.nameTarget?.value?.trim()

    if (!gameId) {
      this.logMessage("Please enter a game ID.", true)
      return
    }

    if (!name) {
      this.logMessage("Please choose a display name.", true)
      return
    }

    this.playerName = name
    this.gameId = gameId
    this.localLog = []

    this.ensureConsumer()
    this.unsubscribe()

    const joinPayload = { action: "join", playerId: this.playerIdValue, name }
    const controller = this

    this.statusTarget.textContent = `Connecting to ${gameId}…`

    this.subscription = this.consumer.subscriptions.create(
      { channel: "DurakChannel", game_id: gameId, player_id: this.playerIdValue },
      {
        connected () {
          controller.logMessage(`Connected to ${gameId}.`)
          this.send(joinPayload)
        },
        rejected () {
          controller.logMessage("Unable to join that table.", true)
        },
        received (data) {
          controller.handleReceived(data)
        },
        disconnected () {
          controller.logMessage("Disconnected from the table.", true)
          controller.setButtonDisabled(controller.pickupButtonTarget, true)
          controller.setButtonDisabled(controller.endTurnButtonTarget, true)
        }
      }
    )
  }

  startGame (event) {
    if (event) event.preventDefault()
    if (!this.subscription) {
      this.logMessage("Join a table before starting a game.", true)
      return
    }
    this.subscription.send({ action: "start", playerId: this.playerIdValue })
  }

  pickup (event) {
    if (event) event.preventDefault()
    if (!this.subscription) return
    this.subscription.send({ action: "pickup", playerId: this.playerIdValue })
  }

  endTurn (event) {
    if (event) event.preventDefault()
    if (!this.subscription) return
    this.subscription.send({ action: "end_turn", playerId: this.playerIdValue })
  }

  playCard (event) {
    event.preventDefault()
    if (!this.subscription || !this.state) return

    const button = event.currentTarget
    const payload = button.dataset.card
    if (!payload) return

    const card = JSON.parse(payload)

    if (this.isAttacker()) {
      this.subscription.send({ action: "attack", playerId: this.playerIdValue, card })
    } else if (this.isDefender()) {
      const index = this.firstUnbeatenPairIndex()
      if (index === -1) {
        this.logMessage("All attacks are defended.")
        return
      }
      this.subscription.send({ action: "defend", playerId: this.playerIdValue, card, pairIndex: index })
    } else {
      this.logMessage("Only the attacker or defender can play cards right now.")
    }
  }

  handleReceived (data) {
    if (!data) return

    if (data.type === "state") {
      this.state = data.state
      this.renderState()
    } else if (data.type === "hand") {
      this.handState = data.hand || []
      this.renderHand()
    } else if (data.type === "error") {
      this.logMessage(data.message, true)
    } else if (data.type === "info") {
      this.logMessage(data.message)
    }
  }

  renderState () {
    if (!this.state) return

    const { status, message, trump_card: trumpCard, deckCount, discardCount, log: remoteLog } = this.state

    if (message) {
      this.logMessage(message)
    }

    if (status === "waiting") {
      this.statusTarget.textContent = "Waiting for more players…"
    } else if (status === "playing") {
      const attackerName = this.playerNameById(this.state.attacker)
      const defenderName = this.playerNameById(this.state.defender)
      if (attackerName && defenderName) {
        this.statusTarget.textContent = `${attackerName} is attacking ${defenderName}.`
      } else {
        this.statusTarget.textContent = "The game is underway."
      }
    } else if (status === "finished") {
      this.statusTarget.textContent = message || "The round has finished."
    }

    this.trumpTarget.textContent = trumpCard ? this.cardLabel(trumpCard) : "—"
    this.deckCountTarget.textContent = typeof deckCount === "number" ? deckCount : (this.state.deck_count || 0)
    this.discardCountTarget.textContent = typeof discardCount === "number" ? discardCount : (this.state.discard_count || 0)

    this.renderPlayers()
    this.renderTable()
    this.renderHand()

    this.remoteLog = Array.isArray(remoteLog) ? remoteLog : []
    this.renderLog()
    this.updateControls()
  }

  renderPlayers () {
    if (!this.hasPlayersListTarget) return
    this.playersListTarget.innerHTML = ""

    if (!this.state || !Array.isArray(this.state.players)) return

    this.state.players.forEach((player) => {
      const wrapper = document.createElement("div")
      wrapper.classList.add("durak__player")
      if (player.id === this.state.attacker) wrapper.classList.add("durak__player--attacker")
      if (player.id === this.state.defender) wrapper.classList.add("durak__player--defender")
      if (player.handCount === 0 && this.state.status === "finished") wrapper.classList.add("durak__player--done")

      const name = document.createElement("div")
      name.classList.add("durak__playerName")
      name.textContent = player.name || "Anonymous"

      const info = document.createElement("div")
      info.classList.add("durak__playerInfo")
      info.textContent = `${player.handCount} card${player.handCount === 1 ? "" : "s"}`

      wrapper.appendChild(name)
      wrapper.appendChild(info)
      this.playersListTarget.appendChild(wrapper)
    })
  }

  renderTable () {
    if (!this.hasTablePairsTarget) return
    this.tablePairsTarget.innerHTML = ""

    if (!this.state || !Array.isArray(this.state.table)) return

    if (this.state.table.length === 0) {
      const empty = document.createElement("p")
      empty.classList.add("durak__empty")
      empty.textContent = "No cards on the table yet."
      this.tablePairsTarget.appendChild(empty)
      return
    }

    this.state.table.forEach((pair, index) => {
      const row = document.createElement("div")
      row.classList.add("durak__tablePair")
      if (!pair.defense) row.classList.add("durak__tablePair--open")
      if (index === this.firstUnbeatenPairIndex()) row.classList.add("durak__tablePair--active")

      const attack = document.createElement("div")
      attack.classList.add("durak__card", "durak__card--attack")
      attack.textContent = this.cardLabel(pair.attack)

      row.appendChild(attack)

      const defense = document.createElement("div")
      defense.classList.add("durak__card", "durak__card--defense")
      defense.textContent = pair.defense ? this.cardLabel(pair.defense) : "—"
      row.appendChild(defense)

      this.tablePairsTarget.appendChild(row)
    })
  }

  renderHand () {
    if (!this.hasHandCardsTarget) return
    this.handCardsTarget.innerHTML = ""

    if (!Array.isArray(this.handState) || this.handState.length === 0) {
      const empty = document.createElement("p")
      empty.classList.add("durak__empty")
      empty.textContent = this.subscription ? "You have no cards." : "Join a table to receive cards."
      this.handCardsTarget.appendChild(empty)
      return
    }

    this.handState.forEach((card) => {
      const button = document.createElement("button")
      button.classList.add("durak__card", "durak__card--hand")
      button.textContent = this.cardLabel(card)
      button.dataset.card = JSON.stringify(card)
      button.setAttribute("type", "button")
      button.addEventListener("click", this.playCard.bind(this))
      this.handCardsTarget.appendChild(button)
    })
  }

  renderLog () {
    if (!this.hasLogTarget) return

    const remoteEntries = (this.remoteLog || []).map((entry) => ({ text: entry, variant: "remote" }))
    const combined = [...remoteEntries, ...this.localLog]
    const recent = combined.slice(-30)

    this.logTarget.innerHTML = ""

    recent.forEach((entry) => {
      const item = document.createElement("p")
      item.textContent = entry.text
      item.classList.add("durak__logEntry")
      if (entry.variant === "error") item.classList.add("durak__logEntry--error")
      if (entry.variant === "local") item.classList.add("durak__logEntry--local")
      this.logTarget.appendChild(item)
    })
    this.logTarget.scrollTop = this.logTarget.scrollHeight
  }

  updateControls () {
    if (!this.subscription || !this.state) {
      this.setButtonDisabled(this.pickupButtonTarget, true)
      this.setButtonDisabled(this.endTurnButtonTarget, true)
      this.setButtonDisabled(this.startButtonTarget, true)
      return
    }

    const canStart = this.state.status === "waiting" && this.state.players?.length >= 2 && this.isHost()
    this.setButtonDisabled(this.startButtonTarget, !canStart)

    const canPickup = this.isDefender() && this.state.table?.length > 0 && this.state.status === "playing"
    this.setButtonDisabled(this.pickupButtonTarget, !canPickup)

    const allDefended = this.allPairsDefended()
    const canEnd = this.isAttacker() && this.state.table?.length > 0 && allDefended && this.state.status === "playing"
    this.setButtonDisabled(this.endTurnButtonTarget, !canEnd)
  }

  logMessage (message, isError = false) {
    if (!message) return
    const variant = isError ? "error" : "local"
    this.localLog.push({ text: message, variant })
    if (this.localLog.length > 30) {
      this.localLog = this.localLog.slice(-30)
    }
    this.renderLog()
  }

  ensureConsumer () {
    if (!this.consumer) {
      this.consumer = createConsumer()
    }
  }

  unsubscribe () {
    if (this.subscription) {
      this.subscription.unsubscribe()
      this.subscription = null
    }
  }

  setButtonDisabled (button, disabled) {
    if (!button) return
    if (disabled) {
      button.setAttribute("disabled", "disabled")
    } else {
      button.removeAttribute("disabled")
    }
  }

  allPairsDefended () {
    if (!this.state || !Array.isArray(this.state.table)) return false
    return this.state.table.every((pair) => pair.defense)
  }

  firstUnbeatenPairIndex () {
    if (!this.state || !Array.isArray(this.state.table)) return -1
    return this.state.table.findIndex((pair) => !pair.defense)
  }

  isAttacker () {
    return this.state && this.state.attacker === this.playerIdValue
  }

  isDefender () {
    return this.state && this.state.defender === this.playerIdValue
  }

  isHost () {
    if (!this.state || !Array.isArray(this.state.players) || this.state.players.length === 0) return false
    return this.state.players[0].id === this.playerIdValue
  }

  playerNameById (id) {
    if (!this.state || !Array.isArray(this.state.players)) return null
    const found = this.state.players.find((player) => player.id === id)
    return found ? found.name : null
  }

  cardLabel (card) {
    if (!card) return "?"
    return `${card.rank}${card.suit}`
  }

  generateId () {
    if (window.crypto && window.crypto.getRandomValues) {
      const array = new Uint32Array(2)
      window.crypto.getRandomValues(array)
      return Array.from(array).map((num) => num.toString(36)).join("").slice(0, 12)
    }
    return `${Date.now().toString(36)}${Math.random().toString(36).slice(2, 8)}`
  }
}
