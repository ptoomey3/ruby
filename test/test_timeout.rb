require 'test/unit'
require 'timeout'
require 'thread'

class TestTimeout < Test::Unit::TestCase
  def test_queue
    q = Queue.new
    assert_raise(Timeout::Error, "[ruby-dev:32935]") {
      timeout(0.01) { q.pop }
    }
  end

  def test_timeout
    flag = true
    Thread.start {
      sleep 0.01
      flag = false
    }
    assert_nothing_raised("[ruby-dev:38319]") do
      Timeout.timeout(1) {
        Thread.pass while flag
      }
    end
    assert !flag, "[ruby-dev:38319]"
  end

  def test_cannot_convert_into_time_interval
    bug3168 = '[ruby-dev:41010]'
    def (n = Object.new).zero?; false; end
    assert_raise(TypeError, bug3168) {Timeout.timeout(n) { sleep 0.1 }}
  end

  def test_skip_rescue
    bug8730 = '[Bug #8730]'
    e = nil
    assert_raise_with_message(Timeout::Error, /execution expired/, bug8730) do
      timeout 0.01 do
        begin
          sleep 3
        rescue Exception => e
        end
      end
    end
    assert_nil(e, bug8730)
  end

  def test_rescue_exit
    exc = Class.new(RuntimeError)
    e = nil
    assert_nothing_raised(exc) do
      timeout 0.01, exc do
        begin
          sleep 3
        rescue exc => e
        end
      end
    end
    assert_raise_with_message(exc, /execution expired/) {raise e if e}
  end

  def test_custom_exception
    bug9354 = '[ruby-core:59511] [Bug #9354]'
    err = Class.new(StandardError) do
      def initialize(msg) super end
    end
    assert_nothing_raised(ArgumentError, bug9354) do
      assert_equal(:ok, timeout(100, err) {:ok})
    end
  end

  def test_exit_exception
    assert_raise_with_message(Timeout::ExitException, "boon") do
      Timeout.timeout(10, Timeout::ExitException) do
        raise Timeout::ExitException, "boon"
      end
    end
  end

  def test_enumerator_next
    bug9380 = '[ruby-dev:47872] [Bug #9380]: timeout in Enumerator#next'
    e = (o=Object.new).to_enum
    def o.each
      sleep
    end
    assert_raise_with_message(Timeout::Error, 'execution expired', bug9380) do
      Timeout.timeout(0.01) {e.next}
    end
  end
end
