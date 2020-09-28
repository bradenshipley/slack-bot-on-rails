# frozen_string_literal: true

# add the named category to the current thread and
# reply in Slack thread w/ the updated category list.
class AddThreadCategoryJob < ApplicationJob
  # Default settings for this job. These are optional - without them, jobs
  # will default to priority 100 and run immediately.
  # self.run_at = proc { 1.minute.from_now }

  # We use the Linux priority scale - a lower number is more important.
  self.priority = 100

  def run(event_id:, options:)
    message = 'An unexpected error occurred. :shrug:'
    event = SlackEvent.find(event_id)
    slack_thread = SlackThread.find_or_initialize_by_event(event)
    slack_thread.category_list.add(options)

    SlackThread.transaction do
      message = if slack_thread.save
                  "#{options} added. Categories: #{slack_thread.category_list}."
                else
                  "There were errors. #{slack_thread.errors.full_messages.join('. ')}. :shrug:"
                end

      event.update(state: 'replied')
      # destroy the job when finished
      destroy
    end

    # post message in slack thread
    slack_thread.post_message(message)
  end
end
