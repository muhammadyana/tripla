module Api
  module V1
    class FollowsController < ApplicationController
      before_action :set_user
      before_action :validate_set_target_user_id
      before_action :set_target_user, only: %i[follow unfollow]

      def follow
        if @user.following?(@target_user)
          responder(:conflict, "You are already following #{@target_user.name}")
        elsif @user.follow(@target_user)
          responder(:created, "Successfully followed #{@target_user.name}")
        else
          responder(:unprocessable_content, "Cannot follow yourself")
        end
      end

      def unfollow
        if @user.following?(@target_user)
          @user.unfollow(@target_user)
          responder(:ok, "Successfully unfollowed #{@target_user.name}")
        else
          responder(:not_found, "You are not following #{@target_user.name}")
        end
      end

      private

      def set_user
        @user = User.find(params[:user_id])
      end

      def set_target_user
        @target_user = User.find(params[:target_user_id])
      end

      def validate_set_target_user_id
        params.require(:target_user_id)
      end
    end
  end
end
