module Loader::Batches::RefreshSortKey
  def prep_refresh_syn_sort_key
    render 'loader/batches/tabs/ordering/prep_refresh_syn_sort_key'
  end

  def cancel_refresh_syn_sort_key
    render 'loader/batches/tabs/ordering/cancel_refresh_syn_sort_key'
  end

  def refresh_syn_sort_keys
    raise 'Not authorised' unless can?("batches", :update)
    @loader_batch.refresh_synonym_sort_keys
    @message = 'Refreshed synonym sort key values'
    render 'loader/batches/tabs/ordering/refresh_syn_sort_key'
  rescue => e
    @message = "Error: #{e.to_s}"
    render :update_error
  end
end
