# frozen_string_literal: true

# create tracked slack threads from events
class CreateThreadJob < ApplicationJob
  # Default settings for this job. These are optional - without them, jobs
  # will default to priority 100 and run immediately.
  # self.run_at = proc { 1.minute.from_now }

  # We use the Linux priority scale - a lower number is more important.
  self.priority = 1

  def run(event_id:)
    message = 'Something unexpected happened.'
    event = SlackEvent.find(event_id)
    slack_thread = SlackThread.find_or_initialize_by_event(event)

    SlackThread.transaction do
      message = if slack_thread.persisted?
                  "#{slack_thread.formatted_link.capitalize} is already being tracked. :white_check_mark:"
                elsif slack_thread.save
                  "Now tracking #{slack_thread.formatted_link}. :white_check_mark:"
                else
                  ":shrug: There were errors. #{slack_thread.errors.full_messages.join('. ')}"
                end

      event.update(state: 'replied')
      # destroy the job when finished
      destroy
    end

    # post message in slack thread
    slack_thread.post_message(message)
  end
end
