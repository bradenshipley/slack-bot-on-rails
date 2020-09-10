class SlackThread < ApplicationRecord
  def self.datetime_from_message_ts(message_ts:, default: DateTime.now)
    Time.at(message_ts.split('.').first.to_i) rescue default
  end

  def self.from_command(client:, data:)
    channel = data.channel
    message_ts = data.thread_ts || data.ts
    permalink = permalink_for(client: client, channel: channel, message_ts: message_ts)
    started_at = datetime_from_message_ts(message_ts: message_ts)
    self.new(channel: channel, permalink: permalink, slack_ts: message_ts, started_at: started_at)
  end

  def self.permalink_for(client:, channel:, message_ts:)
    response = client.web_client.chat_getPermalink(channel: channel, message_ts: message_ts)
    response&.permalink
  end

  # Move this into React?
  def now_tracking
    <<~EOS
      Now tracking <#{permalink}|this thread>,
      which started at #{ I18n.l(started_at, format: :long) }.
    EOS
  end
end
