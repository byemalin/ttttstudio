# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end


# db/seeds.rb

# 1) Find the users in the DB
rocco = User.find_by(email: "rocco.montagnoli@gmail.com")
malin = User.find_by(email: "malin@byemalin.com")

# 2) Create the posts. Each is stored as rich text with inline <figure> tags.
Post.create!([
  {
    title: "How To Go Through a Door",
    body: <<~HTML,
      I love the concept of deeply explaining processes that might seem simple to everyday life, but once we look into them, they can actually get to be very detailed indeed. Julio Cortázar once wrote “Instrucciones para subir una escalera” (Instructions on how to climb a staircase) a profond explaination on how we should embark the simple act of going from one floor to the other, while at the same time, setting your mind to the task and getting something more out of that simple action. Not long ago, I found this finnish video in which a very dapper and decided man offers a guide on how one should tresspass a threshold between two rooms in an immaculate, perfect manner, each and every single time this is done. I encourage you to begin to look at everything you do in this way, doing every step with an unexpected amount of attention and love.
    HTML
    user: rocco,
    created_at: Time.zone.parse("2022-02-10 17:14"),
    city: "Paris",
    country: "France"
  },
  {
    title: "Remind me to drink water",
    body: <<~HTML,
      I didn’t use to have problems with hydration as a kid, I was always thirsty, therefore I always drank water. As I grew up I started to get inhibited by external factors in an increasing manner, leaving me today in a situation in which I have to constantly remind myself to take a gulp out of the bottle I had sitting by me all morning, and that rarely leaves my side.<br><br>

      The issue isn’t that I replace my water drinking with soda drinking or anything else (Maybe sometimes I do replace it with coffee, but not to quench my thirst), or that I don’t like water, don’t get me wrong, I love water almost more than anything in the world, but I forget to drink it.<br><br>

      When I’m in a water drinking streak, I tend to think and question for what reason in the world would I not be drinking it, but two weeks after, there I am again, not drinking water.<br><br>

      I guess I need to start building the habit of reminding myself to stay more in line more often.
    HTML
    user: rocco,
    created_at: Time.zone.parse("2022-02-04 21:20"),
    city: "Paris",
    country: "France"
  },
  {
    title: "Low-res, high quality",
    body: <<~HTML,
      Low-quality content seems to be becoming increasingly popular in contemporary media. I’m talking about unpolished photos and videos and memes that intentionally make no sense.<br><br>

      This is by no means a new idea and I’m not saying anything revolutionary. Picasso strove to learn to unlearn complex techniques and remove restrictions from his practice leading to some of his best work. A lot of our generation is trying to disregard and dismantle societal expectations created by ourselves and our recent predecessors in regards to social media.<br><br>

      Very often I get an idea for a video that I want to make but I end up procrastinating it because I don’t have a good quality camera on me (I sold my camera to buy track-packing supplies lmao). Thinking like this leads to me abandoning so many ideas. Most of the time, I should just go ahead and use the camera on my phone. The content of the video is far more important than the resolution, and I can always go back and re-film something in higher quality if it seems necessary for a specific video. Not starting a task because you don’t think it will be high enough quality becomes a perpetual excuse for so many tasks in all aspects of life.<br><br>

      Instagram is a good place to witness what I’m talking about. Typically Instagram is a relatively toxic place where people only post the best aspects of themselves and their lives. For a lot of people, Instagram is a platform for posting curated, edited, polished photos and videos. However, over the last year or so you can see more and more people posting photo dumps with random content from their camera rolls, with no editing, and seemingly more candid moments. Of course, there have always been people doing this, people that were always ‘too cool to care or whatever, but that’s beside the point. The point is that these posts that seem ‘too cool to care’ are now trending. I’m also not going to go into the obvious issue of people carefully curating photo dumps to seem candid when they are not. For the sake of this writing, people that are actually too cool to care, and people that are pretending to be too cool to care can be considered the same. Regardless, it seems that lower quality, less polished, and less curated images are gaining in popularity.<br><br>

      Memes are another pretty clear example. Perhaps they just highlight the dysfunctional reality that Generation Z experiences.<br><br>

      Here’s an example of a meme that used to be funny:
      <figure class="attachment attachment--preview">
        <img src="https://byemalin.github.io/TTTT_WEBSITE/Assets/img/cats_meme.jpeg" alt="cats_meme">
      </figure>

      Here’s an example of a more contemporary meme that is for some reason considered funny:
      <figure class="attachment attachment--preview">
        <img src="https://byemalin.github.io/TTTT_WEBSITE/Assets/img/boys_beans.png" alt="boys_beans">
      </figure>

      I guess that fact that this makes no sense and has no basis for comedy is what makes many enjoy this type of content. I see our love for lower fidelity content as an acknowledgement of the absurdity and meaningless of so many things we as a society hold in high regard. Seeing such content made me realise that my iPhone camera was enough.<br><br>

      I couldn’t care less about the Mona Lisa. I mean it genuinely when I say I’m more interested in the stickman you drew on a napkin that time in a restaurant when you were 9. Do you know what I mean? I think many do.<br><br>

      This attitude of not having to make everything seem perfect, and striving for imperfection can be so beneficial to one's output as a creative. Perfection is a waste of time and energy. For example, it might take 100 units of work to get your task to 70% quality. But, often you end up using more than 100 units on top of that to try to get that last 30%. Yeah, once in a while that may be worth it, but I think that most of the time the energy spent going for that last 30 would’ve been better spent getting a different project to 70% and stopping at 70%. I’d rather have loads of projects that are good enough, than only a few that are close to perfect. I'd like to think that this website is a good example too, it's pretty much just bare Html and basic CSS without overthinking the design. That's not to say that the design won't be developed further, because it will be.
    HTML
    user: malin,
    created_at: Time.zone.parse("2022-01-08 14:13"),
    city: "Newport Beach",
    country: "US"
  },
  {
    title: "Sustainable Buying",
    body: <<~HTML,
      I’ve been riding fixed gear bikes for the past 6 years, (first 4 on and off, last 2 fully involved in the matter) and I’ve always found myself stagnated at the time of buying for a new pair to destroy whilst on the bike. Last year I went to visit a good friends family house in Marbella, and his dad (he really my friend too) surprised me in the morning one day offering me a pair of Prada shoes (the ones that look like if some low Chucks had a baby with the highest quality leather Dunks you’ve ever seen, see attachment) that didn’t fit him and he got tired of. Of course I took them, nothing screams nice leather like that Prada red tag on the heel does. So far, they’ve been my daily uniform shoes (at least for the nicer weather days) mainly because of how well they perform on the track bike! I’ve been through heaven and hell in these shoes, I even took them to trackpacking from Rome to Naples as my odd pair (other pair was cycling shoes, and of course the trusty ‘ole Birkies[s.o. Brooklyn Birkie Boys]) So yeah, I’d say these shoes were a great lesson on sustainable buying, buy good quality stuff that’ll last you longer than you’d expect it to, and you’ll be happy with the result.<br><br>

      <figure class="attachment attachment--preview">
        <img src="https://byemalin.github.io/TTTT_WEBSITE/Assets/img/Sustainable_Buying%20_Prada_Shoes.png" alt="Prada_Shoes">
      </figure>
    HTML
    user: rocco,
    created_at: Time.zone.parse("2021-12-09 07:31"),
    city: "Paris",
    country: "France"
  },
  {
    title: "Collective Consciousness",
    body: <<~HTML,
      Not long ago I read an article about German-American psychologist Wolfgang Köhler, who conducted a study in 1929 where they asked different populations (Tamil speakers in India, Tenerifeans, young children, infants, and American university students) to decide which shape fit “takete” and which fit “baluba”. In all the cases, it was agreed that the shape with the rounded ends should be named “baluba”, and the shape with the sharp ends, “takete”. I think It’s interesting to think, how natural our collective (in)consciousness actually is, and how design and ergonomy are fully rooted in these human brain tendencies. I guess we’re really humans after all.<br><br>

      <figure class="attachment attachment--preview">
        <img src="https://byemalin.github.io/TTTT_WEBSITE/Assets/img/collective_cons.jpg" alt="collective_cons">
      </figure>
    HTML
    user: rocco,
    created_at: Time.zone.parse("2021-11-28 07:25"),
    city: "Paris",
    country: "France"
  }
])

puts "Seeded 5 old posts with inline images!"
