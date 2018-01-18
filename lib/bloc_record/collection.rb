module BlocRecord
  class Collection < Array
    def update_all(updates)
      ids = self.map(&:id)
      self.any? ? self.first.class.update(ids, updates) : false
    end

    def take(num=1)
      loop_point = 0
      while loop_point < num
        puts self.sample
        loop_point += 1
      end
    end

    def where(params)
      results = BlocRecord::Collection.new
      params_to_meet = params.keys.length

      self.each do |item|
        params_met = 0
        params.each do |k, v|
          if item.send(k) == v
            params_met += 1
            params_to_meet == params_met && results.include?(item) == false ? results << item
          end
        end
      end
      results

      self.select do |item|
        params.all? |key, value|
          item.send(key) == value
      end
    end
  end

  def not(params)
    results = BlocRecord::Collection.new
    self.each do |item|
      params.each do |k, v|
        item.send(k) != v && results.include?(item) == false ? results << item
      end
    end
    results

    self.select do |item|
      !params.any? |key, value|
        item.send(key) == value
      end
    end
  end

  def destroy_all
    self.each do |element|
      element.destroy
      puts "#{element} was deleted from the database"
    end
  end
end
