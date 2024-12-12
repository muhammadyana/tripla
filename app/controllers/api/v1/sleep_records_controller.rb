module Api
  module V1
    class SleepRecordsController < ApplicationController

      def index
        sleep_records = Rails.cache.fetch("user_sleep_records_#{current_user.id}", expires_in: 1.hour) do
          current_user.sleep_records.desc
        end
        responder(:ok, SleepRecordSerializer.new(sleep_records))
      end

      def clock_in
        current_user.sleep_records.where(clock_out_time: nil).update_all(clock_out_time: Time.current)

        current_user.sleep_records.create!(clock_in_time: Time.current)

        sleep_records = current_user.sleep_records.desc
        responder(:created, SleepRecordSerializer.new(sleep_records))
      end

      def following_sleep_records
        sleep_records = Rails.cache.fetch("following_sleep_records_#{current_user.id}", expires_in: 1.hour) do
          SleepRecord
            .joins(:user)
            .merge(User.joins(:followers).where(followers: { id: current_user.id }))
            .for_week
            .completed
            .order(duration_seconds: :desc)
        end

        responder(:ok, SleepRecordSerializer.new(sleep_records))
      end
    end
  end
end
