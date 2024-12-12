module Api
  module V1
    class SleepRecordsController < ApplicationController
      before_action :validate_user_id
      before_action :set_user

      def index
        sleep_records = @user.sleep_records.desc
        responder(:ok, SleepRecordSerializer.new(sleep_records))
      end

      def clock_in
        @user.sleep_records.where(clock_out_time: nil).update_all(clock_out_time: Time.current)

        @user.sleep_records.create!(clock_in_time: Time.current)

        sleep_records = @user.sleep_records.desc
        responder(:created, SleepRecordSerializer.new(sleep_records))
      end

      def following_sleep_records
        sleep_records = SleepRecord
          .joins(:user)
          .merge(User.joins(:followers).where(followers: { id: @user.id }))
          .for_week
          .completed
          .order(duration_seconds: :desc)

        responder(:ok, SleepRecordSerializer.new(sleep_records))
      end

      private

      def validate_user_id
        params.require(:user_id)
      end

      def set_user
        @user = User.find(params[:user_id])
      end
    end
  end
end
