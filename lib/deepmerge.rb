class Hash
  DEEP_MERGER = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &DEEP_MERGER) : v2 }

  # Deep merges hashes. OVERWRITES NON-HASH MEMBERS (Including arrays of hashes!)
  # @param [Hash] second
  def deep_merge(second)
    self.merge(second, &DEEP_MERGER)
  end
  # Deep merges hashes. OVERWRITES NON-HASH MEMBERS (Including arrays of hashes!)
  # @param [Hash] second
  def deep_merge!(second)
    unless second.empty?
      self.merge!(second, &DEEP_MERGER)
    end
    self
  end
end
