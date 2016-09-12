module OrigenTesters
  MAJOR = 0
  MINOR = 7
  BUGFIX = 13
  DEV = nil

  VERSION = [MAJOR, MINOR, BUGFIX].join(".") + (DEV ? ".pre#{DEV}" : '')
end
