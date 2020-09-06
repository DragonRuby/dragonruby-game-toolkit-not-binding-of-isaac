# @param [Proc] code
# @param [TrueClass, FalseClass] print
# @param [String] method_name
def profile(method_name = "anonymous", print = false, &code)
  start_time = Time.now
  out        = code.call
  t          = Time.now - start_time
  if t.to_f.round(3) > 0.001
    puts "`#{method_name}` took #{t.to_f.round(3).to_s} seconds" if print
  end
  [out, t.to_f]
end