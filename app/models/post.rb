class Post < ApplicationRecord
  belongs_to :user
  has_many_attached :images, dependent: :destroy

  # Validations
  validates :city, presence: true
  validates :country, presence: true
end
