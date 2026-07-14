class DemoBoard
  def self.create!
    users = [
      User.create!(name: "Avery Chen", email: "avery@example.test"),
      User.create!(name: "Mira Shah", email: "mira@example.test"),
      User.create!(name: "Jon Bell", email: "jon@example.test")
    ]

    Board.create!(name: "Personal Kanban", description: "A lightweight planning board.").tap do |board|
      backlog = board.columns.create!(name: "Backlog", position: 1, wip_limit: 8)
      ready = board.columns.create!(name: "Ready", position: 2, wip_limit: 5)
      doing = board.columns.create!(name: "Doing", position: 3, wip_limit: 3)
      done = board.columns.create!(name: "Done", position: 4)

      backlog.cards.create!(
        title: "Sketch board workflow",
        description: "Define columns, fields, and move behavior.",
        priority: "high",
        due_on: Date.current + 2.days,
        estimate: 3,
        labels: "planning,ux",
        assignee: users.first,
        position: 1
      )
      ready.cards.create!(
        title: "Wire card assignment",
        description: "Assign cards without leaving the board.",
        priority: "medium",
        due_on: Date.current + 4.days,
        estimate: 2,
        labels: "rails,hotwire",
        assignee: users.second,
        position: 1
      )
      doing.cards.create!(
        title: "Persist drag and drop",
        description: "Use Stimulus to send the new column and list position.",
        priority: "urgent",
        due_on: Date.current + 1.day,
        estimate: 5,
        labels: "stimulus",
        assignee: users.third,
        position: 1
      )
      done.cards.create!(
        title: "Choose POC stack",
        description: "Rails, Hotwire, SQLite, and acts_as_list.",
        priority: "low",
        labels: "architecture",
        position: 1
      )
    end
  end
end
