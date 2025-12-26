require "test_helper"

class ReceiptCounterTest < ActiveSupport::TestCase
  test "starts from 1" do
    number = ReceiptCounter.next_number(2025, "A")
    assert_equal 1, number

    # Verifica nel DB
    counter = ReceiptCounter.find_by(year: 2025, sequence_category: "A")
    assert_equal 1, counter.last_number
  end

  test "increments sequentially" do
    assert_equal 1, ReceiptCounter.next_number(2025, "B")
    assert_equal 2, ReceiptCounter.next_number(2025, "B")
    assert_equal 3, ReceiptCounter.next_number(2025, "B")
  end

  test "separates sequences by year and category" do
    # Anno 2025, Cat A
    assert_equal 1, ReceiptCounter.next_number(2025, "A")

    # Anno 2025, Cat B (Deve ripartire da 1)
    assert_equal 1, ReceiptCounter.next_number(2025, "B")

    # Anno 2026, Cat A (Deve ripartire da 1)
    assert_equal 1, ReceiptCounter.next_number(2026, "A")
  end

  test "handles race conditions correctly (Concurrency Test)" do
    # --- SETUP DELLO STRESS TEST ---
    year = 2099 # Anno futuro per evitare conflitti
    category = "STRESS"

    # Creiamo il record iniziale per testare puramente l'incremento atomico
    # (Il lock serve soprattutto sull'incremento)
    ReceiptCounter.create!(year: year, sequence_category: category, last_number: 0)

    # Configuriamo i parametri di carico
    threads_count = 5   # Simuliamo 5 operatori simultanei
    increments_per_thread = 50 # Ognuno fa 50 vendite
    expected_total = threads_count * increments_per_thread # 250 vendite totali

    # --- ESECUZIONE PARALLELA ---
    threads = threads_count.times.map do
      Thread.new do
        # Importante: Ogni thread deve avere la sua connessione al DB
        ActiveRecord::Base.connection_pool.with_connection do
          increments_per_thread.times do
            ReceiptCounter.next_number(year, category)
          end
        end
      end
    end

    # Aspettiamo che tutti i thread finiscano
    threads.each(&:join)

    # --- VERIFICA ---
    final_counter = ReceiptCounter.find_by(year: year, sequence_category: category)

    # Se ci fosse una race condition, il numero sarebbe MINORE di 250
    # (perché alcuni thread avrebbero sovrascritto il lavoro di altri)
    assert_equal expected_total, final_counter.last_number,
      "Race condition rilevata! Il contatore dovrebbe essere #{expected_total} ma è #{final_counter.last_number}"
  end
end
