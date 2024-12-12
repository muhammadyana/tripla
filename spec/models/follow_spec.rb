# == Schema Information
#
# Table name: follows
#
#  id          :integer          not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  followed_id :integer          not null
#  follower_id :integer          not null
#
# Indexes
#
#  index_follows_on_followed_id                  (followed_id)
#  index_follows_on_follower_id                  (follower_id)
#  index_follows_on_follower_id_and_followed_id  (follower_id,followed_id) UNIQUE
#
# Foreign Keys
#
#  followed_id  (followed_id => users.id)
#  follower_id  (follower_id => users.id)
#
require 'rails_helper'

RSpec.describe Follow, type: :model do
  describe 'associations' do
    it { should belong_to(:follower).class_name('User') }
    it { should belong_to(:followed).class_name('User') }
  end

  describe 'validations' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    subject { create(:follow, follower: user1, followed: user2) }

    it { should validate_uniqueness_of(:follower_id).scoped_to(:followed_id) }
  end
end
