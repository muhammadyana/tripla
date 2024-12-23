class AddSleepRecordsIndexes < ActiveRecord::Migration[7.2]
  def change
    add_index :sleep_records, [:user_id, :clock_in_time] unless index_exists?(:sleep_records, [:user_id, :clock_in_time])
  end
end
