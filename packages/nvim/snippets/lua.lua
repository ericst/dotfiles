return {
  s( "fn", fmt([[
    function {}({})
      {}
    end]], {
      i(1, "fname"),
      i(2),
      i(0, "--code"),
    }
  )),
}

