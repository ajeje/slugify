module Slugify
  class MissingColumnError < StandardError
  end

  def slugify(from_field = :title, options = {})
    options.symbolize_keys!
    options.reverse_merge!({
      :from    => from_field,
      :to      => :slug
    })

    # Make sure the columns exist
    [options[:from], options[:to]].each do |field|
      unless column_names.include?(field.to_s)
        raise MissingColumnError, "Couldn't find column '#{field}' in '#{table_name}'. Perhaps you have a typo or need to migrate your database?"
      end
    end

    # Define instance methods
    class_eval <<-EVAL
      def slugify(force_refresh=false)
        return if self[:#{options[:from]}].nil?

        self[:#{options[:to]}] = if self[:#{options[:to]}].blank? || force_refresh
          # only process from field if slug is blank
          self[:#{options[:from]}].parameterize.to_s
        else
          # always parameterize the slug field, in case the user gives invalid input
          self[:#{options[:to]}].parameterize.to_s
        end
      end

      def slugify!
        slugify(true)
      end
    EVAL

    # Install validations
    validates_presence_of   options[:to]
    validates_uniqueness_of options[:to]
    validates_format_of     options[:to], :with => /^[-_+a-z0-9]+$/

    # Install filters
    before_validation :slugify
  end
end

ActiveRecord::Base.extend(Slugify)
