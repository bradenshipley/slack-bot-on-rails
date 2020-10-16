# frozen_string_literal: true

# create tracked slack threads from events
class CreateThreadJob < ApplicationJob
  # Default settings for this job. These are optional - without them, jobs
  # will default to priority 100 and run immediately.
  # self.run_at = proc { 1.minute.from_now }

  # We use the Linux priority scale - a lower number is more important.
  self.priority = 10

  def run(event_id:, options: nil)
    help = ApplicationController.render(template: 'slack_events/index.slack', layout: nil)
    message = 'An unexpected error occurred. :shrug:'
    event = SlackEvent.find(event_id)
    slack_thread = SlackThread.find_or_initialize_by_event(event)

    SlackThread.transaction do
      message = if slack_thread.persisted?
                  'This thread is already being tracked. :white_check_mark:'
                elsif slack_thread.save
                  CreateIssueJob.enqueue(thread_id: slack_thread.id)
                  "Now tracking #{slack_thread.formatted_link}. :white_check_mark:"
                else
                  "There were errors. #{slack_thread.errors.full_messages.join('. ')}. :shrug:"
                end

      event.update(state: 'replied')
      # destroy the job when finished
      destroy
    end

    # post reply to slack user
    slack_thread.post_ephemeral_reply(message, event.user)
    # post help to slack user
    slack_thread.post_ephemeral_reply(help, event.user)
  end
end
