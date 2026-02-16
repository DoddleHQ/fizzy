class Account::Seeder
  attr_reader :account, :creator

  def initialize(account, creator)
    @account = account
    @creator = creator
  end

  def seed
    Current.set(user: creator, account: account) do
      populate
    end
  end

  def seed!
    raise "You can't run in production environments" unless Rails.env.local?

    delete_everything
    seed
  end

  private
    def populate
      # ---------------
      # Playground Board
      # ---------------
      playground = account.boards.create! name: "Playground", creator: creator, all_access: true
      playground.update! auto_postpone_period: 365.days

      # Cards
      playground.cards.create! creator: creator, title: "Welcome to oCode", status: "published", description: <<~HTML
        <p>There's a whole lot you can do in oCode. This playground board will help you learn the basics.</p>
      HTML

      playground.cards.create! creator: creator, title: "Now, grab the invite link to invite someone else", status: "published", description: <<~HTML
        <p>Open the oCode menu, select "<b><strong>+ Add people</b></strong>", then copy the invite link. You can give this link to someone else so they can make a login for themselves in your account.</p>
      HTML

      playground.cards.create! creator: creator, title: "Then, head back home to check out activity", status: "published", description: <<~HTML
        <p>Hit "1" or pull down the oCode menu and select "Home".</p>
      HTML

      playground.cards.create! creator: creator, title: "Now, check out all cards assigned to you", status: "published", description: <<~HTML
        <p>Pull down the oCode menu at the top of the screen, and select "<b><strong>Assigned to me</b></strong>" or just hit "2" on your keyboard any time.</p>
      HTML

      playground.cards.create! creator: creator, title: "Then, open the oCode menu", status: "published", description: <<~HTML
        <p>The oCode menu is how you get around the app. Click "<b><strong>oCode</b></strong>" at the top of the screen or hit the "J" key on your keyboard to pop it open.</p>
      HTML

      playground.cards.create! creator: creator, title: "Next, assign this card to yourself", status: "published", description: <<~HTML
        <p>Click the little head with the + next to it, then pick yourself.</p>
      HTML

      playground.cards.create! creator: creator, title: 'Now, tag this card "Design" then move it to YES', status: "published", description: <<~HTML
        <p>Click the little Tag icon, type "design", then "<b><strong>Create tag</b></strong>". Then, move the card to the new "YES" column you created in the previous step.</p>
      HTML

      playground.cards.create! creator: creator, title: "Next, make two more columns", status: "published", description: <<~HTML
        <ol>
          <li>Make one called "Yes"</li>
          <li>Make another called "Working on"</li>
        </ol>
        <p>Go back to the Board view, click the little "+" to the right of the DONE column, name the column, pick a color, then do it again.</p>
        <p><br></p>
        <p>After that, drag this card to "DONE" or select "DONE" in the sidebar.</p>
      HTML

      playground.cards.create! creator: creator, title: "Second, move this card to NOT NOW", status: "published", description: <<~HTML
        <p>You can either select "NOT NOW" over in the sidebar, or you can go back out to the board view and drag this card into the "NOT NOW" column on the left side.</p>
        <p><br></p>
      HTML

      playground.cards.create! creator: creator, title: "First, rename this card", status: "published", description: <<~HTML
        <ol>
          <li>Click the title and you can rename the card, change the description, or add more information to the card.</li>
          <li>Then, hit "Mark as Done" at the bottom of the card.</li>
          <li>Finally, hit "<b><strong>Back to Playground</strong></b>" in the top left of the screen to go back to the board.</li>
        </ol>
      HTML
    end

    def delete_everything
      Current.set(user: creator, account: account) do
        account.boards.destroy_all
      end
    end
end
