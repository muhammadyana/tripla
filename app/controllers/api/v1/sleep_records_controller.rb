module Api
  module V1
    class SleepRecordsController < ApplicationController

      def index
        sleep_records = current_user.sleep_records.desc
        responder(:ok, SleepRecordSerializer.new(sleep_records))
      end

      def clock_in
        current_user.sleep_records.where(clock_out_time: nil).update_all(clock_out_time: Time.current)

        current_user.sleep_records.create!(clock_in_time: Time.current)

        sleep_records = current_user.sleep_records.desc
        responder(:created, SleepRecordSerializer.new(sleep_records))
      end

      def following_sleep_records
        sleep_records = SleepRecord
          .joins(:user)
          .merge(User.joins(:followers).where(followers: { id: current_user.id }))
          .for_week
          .completed
          .order(duration_seconds: :desc)

        responder(:ok, SleepRecordSerializer.new(sleep_records))
      end
    end
  end
end
