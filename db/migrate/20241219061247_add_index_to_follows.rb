class AddIndexToFollows < ActiveRecord::Migration[7.2]
  def change
    add_index :follows, :follower_id
    add_index :follows, :followed_id
  end
end
