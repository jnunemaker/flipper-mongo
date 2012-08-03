module AccessorHelpers
  def read_key(key)
    if (doc = collection.find_one(criteria))
      value = doc[key]

      if value.is_a?(::Array)
        value = value.to_set
      end

      value
    end
  end

  def write_key(key, value)
    if value.is_a?(::Set)
      value = value.to_a
    end

    options = {:upsert => true}
    updates = {'$set' => {key => value}}
    collection.update criteria, updates, options
  end
end
