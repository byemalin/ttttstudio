class Take < ApplicationRecord
  belongs_to :user

  # Active Storage association for your optional image
  has_one_attached :photo

  # Validate presence of body, and limit to 280 characters
  validates :body, presence: true, length: { maximum: 280 }
end
