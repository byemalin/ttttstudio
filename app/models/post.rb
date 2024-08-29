class Post < ApplicationRecord
  belongs_to :user

  # Validations
  validates :city, presence: true
  validates :country, presence: true
end
