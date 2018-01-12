module Gitlab
  module SQL
    module Pattern
      extend ActiveSupport::Concern

      MIN_CHARS_FOR_PARTIAL_MATCHING = 3
      REGEX_QUOTED_WORD = /(?<=\A| )"[^"]+"(?= |\z)/

      class_methods do
        def fuzzy_search(query, columns)
          matches = columns.map { |col| fuzzy_arel_match(col, query) }.compact.reduce(:or)

          where(matches)
        end

        def to_pattern(query)
          if partial_matching?(query)
            "%#{sanitize_sql_like(query)}%"
          else
            sanitize_sql_like(query)
          end
        end

        def partial_matching?(query)
          # Support searching with 2 Chinese characters
          query.gsub(/\p{Han}/u, '**').length >= MIN_CHARS_FOR_PARTIAL_MATCHING
        end

        def fuzzy_arel_match(column, query)
          query = query.squish
          return nil unless query.present?

          words = select_fuzzy_words(query)

          if words.any?
            words.map { |word| arel_table[column].matches(to_pattern(word)) }.reduce(:and)
          else
            # No words of at least 3 chars, but we can search for an exact
            # case insensitive match with the query as a whole
            arel_table[column].matches(sanitize_sql_like(query))
          end
        end

        def select_fuzzy_words(query)
          quoted_words = query.scan(REGEX_QUOTED_WORD)

          query = quoted_words.reduce(query) { |q, quoted_word| q.sub(quoted_word, '') }

          words = query.split

          quoted_words.map! { |quoted_word| quoted_word[1..-2] }

          words.concat(quoted_words)

          words.select { |word| partial_matching?(word) }
        end
      end
    end
  end
end
