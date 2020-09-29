# frozen_string_literal: true

FactoryBot.define do
  factory :slack_thread do
    channel { 'ABC123' }
    slack_ts { '1601259545.006300' }

    trait :categories do
      category_list { 'one, two' }
    end

    trait :links do
      link_list { 'https://www.example.com, https://www.test.com' }
    end

    trait :team do
      team
    end
  end
end