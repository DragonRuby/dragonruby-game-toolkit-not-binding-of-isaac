class Hash
  # Deep merges hashes. OVERWRITES NON-HASH MEMBERS (Including arrays of hashes!)
  # @param [Hash] second
  def deep_merge(second)
    merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
    self.merge(second, &merger)
  end
  # Deep merges hashes. OVERWRITES NON-HASH MEMBERS (Including arrays of hashes!)
  # @param [Hash] second
  def deep_merge!(second)
    merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge!(v2, &merger) : v2 } # Is the !merge here safe?
    self.merge!(second, &merger)
  end
end
