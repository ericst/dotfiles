-- Function to calculate date using the GNU date utility
local function date(args, parent, format, precision)
  if format == "ISO" then
    return vim.fn.trim(vim.fn.system("date -I'" .. precision .. "'"))
  else
    return vim.fn.trim(vim.fn.system("date +'" .. format .. " '"))
  end
end

return {
  s( "date",  f(date, {}, { user_args = { "%+4Y-%m-%d" } } )),
  s( "date-day",  f(date, {}, { user_args = { "%+4Y-%m-%d %a", "date" } } )),
  s( "date-day-time",  f(date, {}, { user_args = { "%+4Y-%m-%d %a %H:%M", "date" } } )),
  s( "date-time",  f(date, {}, { user_args = { "%+4Y-%m-%d %H:%M" } } )),
  s( "iso-week",  f(date, {}, { user_args = { "W%V" } } )),
  s( "iso-date-week",  f(date, {}, { user_args = { "%G-W%V" } } )),
  s( "iso-date-minutes",  f(date, {}, { user_args = { "ISO", "minutes" } } )),
  s( "iso-date-seconds",  f(date, {}, { user_args = { "ISO", "seconds" } } )),
}



