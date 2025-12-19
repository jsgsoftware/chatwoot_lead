namespace :chatwoot do
  desc 'Seed sample conversations with different statuses'
  task seed_conversations: :environment do
    account = Account.first || Account.create!(name: 'Test Account')
    user = account.users.first || begin
      u = User.new(name: 'Test User', email: 'test@example.com', password: 'Password1!')
      u.skip_confirmation!
      u.save!
      AccountUser.create!(account: account, user: u, role: :administrator)
      u
    end
    
    inbox = account.inboxes.first || begin
      web_widget = Channel::WebWidget.create!(account: account, website_url: 'https://test.com')
      i = Inbox.create!(channel: web_widget, account: account, name: 'Test Inbox')
      InboxMember.create!(user: user, inbox: i)
      i
    end

    puts "Creating conversations for account: #{account.name}"

    # Crear 3 conversaciones por cada estado
    ['open', 'pending', 'snoozed', 'resolved'].each do |status|
      3.times do |i|
        contact = Contact.create!(
          account: account,
          name: "Contact #{status.capitalize} #{i + 1}",
          email: "contact-#{status}-#{i + 1}@test.com"
        )
        
        contact_inbox = ContactInbox.create!(
          contact: contact,
          inbox: inbox,
          source_id: "source-#{status}-#{i + 1}"
        )
        
        conversation = Conversation.create!(
          account: account,
          inbox: inbox,
          status: status,
          assignee: user,
          contact: contact,
          contact_inbox: contact_inbox
        )
        
        # Crear algunos mensajes
        Message.create!(
          content: "Hello! This is a #{status} conversation",
          account: account,
          inbox: inbox,
          conversation: conversation,
          sender: contact,
          message_type: :incoming
        )
        
        Message.create!(
          content: "Thanks for contacting us!",
          account: account,
          inbox: inbox,
          conversation: conversation,
          sender: user,
          message_type: :outgoing
        )
        
        puts "  ✓ Created #{status} conversation ##{i + 1}"
      end
    end

    puts "\n✓ Created 12 conversations (3 per status)"
    puts "  - 3 Open"
    puts "  - 3 Pending"
    puts "  - 3 Snoozed"
    puts "  - 3 Resolved"
  end
end
