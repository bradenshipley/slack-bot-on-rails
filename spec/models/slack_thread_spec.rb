RSpec.describe SlackThread do
  subject(:thread) { SlackThread.from_command(client: client, data: data) }

  let(:client) { double('Client', web_client: MockSlackClient.new) }
  let(:data) { build_stubbed(:slack_command) }
  let(:started_at) { Time.parse("2020-09-04 18:59:53 UTC") } # thread_ts as UTC date
  let(:permalink) { 'https://example.com/' }

  context 'an untracked thread' do
    context 'from channel' do
      let(:data) { build(:slack_command, thread_ts: nil) }
      let(:started_at) { Time.parse("2020-09-04 19:32:36 UTC") } # ts as UTC date

      describe '#started_at' do
        subject { thread.started_at }
        it { is_expected.to eq(started_at) }
      end

      describe '#slack_ts' do
        subject { thread.slack_ts }
        it { is_expected.to eq(data.ts) }
      end
    end

    context 'from thread' do
      describe '#started_at' do
        subject { thread.started_at }
        it { is_expected.to eq(started_at) }
      end

      describe '#slack_ts' do
        subject { thread.slack_ts }
        it { is_expected.to eq(data.thread_ts) }
      end
    end
  end

  context 'an already tracked thread' do
    subject { thread }

    let(:tracked_thread) { SlackThread.from_command(client: client, data: data) }

    before do
      expect(SlackThread).to receive(:find_by).with(slack_ts: data.thread_ts).and_return(tracked_thread)
    end

    it { is_expected.to eq(tracked_thread) }
  end

  describe '#channel' do
    subject { thread.channel }
    it { is_expected.to eq(data.channel) }
  end

  describe '#permalink' do
    subject { thread.permalink }
    it { is_expected.to eq(permalink) }
  end

  describe '#now_tracking' do
    subject { thread.now_tracking }
    it { is_expected.to include(permalink) }
    it { is_expected.to include(I18n.l(started_at, format: :long)) }
  end
end

class MockSlackClient
  def chat_getPermalink(channel:, message_ts:)
    self
  end

  def permalink
    'https://example.com/'
  end
end