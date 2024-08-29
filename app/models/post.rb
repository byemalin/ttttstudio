class Post < ApplicationRecord
  belongs_to :user
  has_many_attached :images

  # Validations
  validates :city, presence: true
  validates :country, presence: true
end
