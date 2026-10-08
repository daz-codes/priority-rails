# Turns notifications on or off for the browser/device making the request
class PushSubscriptionsController < ApplicationController
  def create
    subscription = PushSubscription.find_or_initialize_by(endpoint: params.dig(:subscription, :endpoint).to_s)
    subscription.assign_attributes(
      user: Current.user, # a shared device signing in as someone else moves to them
      p256dh_key: params.dig(:subscription, :keys, :p256dh),
      auth_key: params.dig(:subscription, :keys, :auth),
      user_agent: request.user_agent
    )

    if subscription.save
      head :created
    else
      render json: { errors: subscription.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    Current.user.push_subscriptions.where(endpoint: params[:endpoint].to_s).destroy_all
    head :no_content
  end
end
