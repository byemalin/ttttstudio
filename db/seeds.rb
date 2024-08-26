# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end




# Test Post

# Find my existing user by email:
user = User.find_by(email: 'malin@byemalin.com')

puts "Seeding Malin's first post"

if user
  Post.create!(
    title: "Reflection on Inspiration",
    body: "Recently I feel like I’ve been able to see art and design in a more objective sense. By that, I mean that I don't feel like I ever need to 'wait' for inspiration to strike, and instead, I'm always ready to brainstorm and work through ideas and problems. Somewhat forcing inspiration is an essential part of a sustainable, repeatable creative process. I love the idea of basing a project around a found object. Michele and I sourced an old, ornate, metal tissue box from a friend of ours that was originally from an antique store. It was full of all these other antiquated objects like watches and lighters and small pieces of jewellery. A box full of memories. Memory, therefore, became the main focus of a short project. We used the box we found, some electrical components, and some relatively simple code to create a memorisation game. Components included buttons, jumper cables, LED’s, a high-frequency buzzer, wire, cardboard and an Elegoo (an off-brand Arduino that works the same for a fraction of the cost). It’s comforting for me when art and design become inseparable. I feel like it’s essential to have a good understanding of complex technical mechanisms whilst giving yourself the freedom to take them apart, turn them inside out, destroy them, and rebuild them with not only a new form and function, but a new fundamental concept.",
    user: user
  )
  puts "Blog post created successfully."
else
  puts "User not found. Please ensure the user with email 'malin@byemalin.com' exists."
end



puts "Database seeded!"
