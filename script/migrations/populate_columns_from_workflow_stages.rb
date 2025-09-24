#!/usr/bin/env ruby

require_relative "../../config/environment"

ApplicationRecord.with_each_tenant do |tenant|
  puts "Processing tenant: #{tenant}"

  Collection.find_each do |collection|
    next unless collection.workflow.present?

    # Map to track stage_id -> column
    columns_by_stage = {}

    # Create columns from workflow stages
    collection.workflow.stages.find_each do |stage|
      column = collection.columns.create!(
        name: stage.name,
        color: stage.color || Card::Colored::COLORS.first
      )
      columns_by_stage[stage] = column
      puts "Created column '#{column.name}' for collection '#{collection.name}'"
    end

    # Associate cards with their corresponding columns based on stages
    collection.cards.includes(:stage).find_each do |card|
      next unless card.stage.present?

      unless card.stage.workflow.collections.include?(collection)
        puts "Corrupt data: the card with id #{card.id} has the stage #{card.stage.name} with id #{card.stage.id} that belongs to a workflow not asociated ot its collection"
        next
      end

      stage = columns_by_stage[card.stage]
      card.update!(column: stage)
      puts "Associated card ##{card.id} with column '#{stage.name}'"
    end
  end
end

puts "Migration completed!"
