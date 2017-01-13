module OrigenTesters
  MAJOR = 0
  MINOR = 8
  BUGFIX = 11
  DEV = nil

  VERSION = [MAJOR, MINOR, BUGFIX].join(".") + (DEV ? ".pre#{DEV}" : '')
end
