module Loader::Batches::MultiplySeqs
  def prep_multiply_seqs_by_10
    render 'loader/batches/tabs/multiply/prep_multiply_seqs_by_10'
  end

  def cancel_multiply_seqs_by_10
    render 'loader/batches/tabs/multiply/cancel_multiply_seqs_by_10'
  end

  def multiply_seqs_by_10
    raise 'Not authorised' unless can?("batches", :update)
    Loader::Name.multiply_seqs_by_10(@loader_batch)
    @message = 'Multiplied by 10'
    render 'loader/batches/tabs/multiply/multiply_all_seqs_by_10'
  rescue => e
    @message = "Error: #{e.to_s}"
    render :update_error
  end
end
