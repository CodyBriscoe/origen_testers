unless $tester.v93k? || $tester.pxie6570? || $tester.stil?
  # Pattern to exercise the memory test feature of tester
  Pattern.create(:memory_test => true) do
    
    $dut.memory_test
    
  end
end
