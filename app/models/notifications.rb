# Push notifications for things other people do. Nobody is notified about their own changes.
module Notifications
  extend self

  def task_added(task, by:)
    list_activity(task.list, by: by, body: "#{by.name} added “#{task.description}”")
  end

  def task_completed(task, by:)
    list_activity(task.list, by: by, body: "#{by.name} completed “#{task.description}”")
  end

  def added_to_list(list, user:, by:)
    return unless user.notify_on_list_invites? && user != by

    send_to [ user.id ], title: "PR!OR!TY!", body: "#{by.name} added you to #{list.name}", url: list_path(list)
  end

  private

  def list_activity(list, by:, body:)
    recipients = list.users.where.not(id: by.id).where(notify_on_list_activity: true)
    # One tag per list, so a burst of changes replaces the previous notification instead of piling up
    send_to recipients.ids, title: list.name, body: body, url: list_path(list), tag: "list-#{list.id}"
  end

  def send_to(user_ids, **payload)
    return if user_ids.empty? || !PushSubscription.enabled?
    return unless PushSubscription.exists?(user_id: user_ids)

    PushNotificationJob.perform_later(user_ids, payload)
  end

  def list_path(list) = Rails.application.routes.url_helpers.list_path(list)
end
