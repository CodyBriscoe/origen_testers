module OrigenTesters
  MAJOR = 0
  MINOR = 7
  BUGFIX = 8
  DEV = nil

  VERSION = [MAJOR, MINOR, BUGFIX].join(".") + (DEV ? ".pre#{DEV}" : '')
end
