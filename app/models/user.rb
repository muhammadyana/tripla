# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class User < ApplicationRecord
  # Relationships
  has_many :sleep_records, dependent: :destroy
  has_many :following_users, foreign_key: :follower_id, class_name: 'Follow'
  has_many :followings, through: :following_users, source: :followed
  has_many :followed_users, foreign_key: :followed_id, class_name: 'Follow'
  has_many :followers, through: :followed_users
end
