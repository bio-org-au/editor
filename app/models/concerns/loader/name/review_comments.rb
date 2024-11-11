module Loader::Name::ReviewComments
  extend ActiveSupport::Concern


  # Narrow direct comments - i.e. for specific, real records
  # like accepted, excluded, and synonym records

  def narrow_direct_reviewer_comments
    real_record_comments(Loader::Batch::Review::Role::NAME_REVIEWER)
  end
  
  def narrow_direct_reviewer_comments?
    narrow_direct_reviewer_comments.size > 0
  end

  def narrow_direct_compiler_comments
    real_record_comments(Loader::Batch::Review::Role::COMPILER)
  end

  def narrow_direct_compiler_comments?
    narrow_direct_compiler_comments.size > 0
  end

  def real_record_comments(role)
    name_review_comments
      .includes(batch_reviewer: [:batch_review_role])
      .select { |comment| comment.reviewer.role.name == role }
      .select { |comment| comment.context == record_type }
  end



  # All comments - needed for totals

  def reviewer_comments
    [narrow_direct_reviewer_comments,
     concept_note_reviewer_comments,
     distribution_reviewer_comments,
     children_reviewer_comments].flatten
  end

  def reviewer_comments?
    reviewer_comments.size > 0
  end

  def compiler_comments
    [narrow_direct_compiler_comments, 
     concept_note_compiler_comments,
     distribution_compiler_comments,
     children_compiler_comments].flatten
  end

  def compiler_comments?
    compiler_comments.size > 0
  end



  # Special total for all comments

  def total_compiler_and_reviewer_comments
    [reviewer_comments, compiler_comments].flatten
  end

  def compiler_or_reviewer_comments?(context = "any")
    total_compiler_and_reviewer_comments.size > 0
  end



  # Comments on children

  def children_reviewer_comments
    children.map do |child| 
      child.name_review_comments
      .includes(batch_reviewer: [:batch_review_role])
      .select { |comment| comment.reviewer.role.name == Loader::Batch::Review::Role::NAME_REVIEWER }
    end.flatten
  end

  def children_compiler_comments
    children.map do |child| 
      child.name_review_comments
      .includes(batch_reviewer: [:batch_review_role])
      .select { |comment| comment.reviewer.role.name == Loader::Batch::Review::Role::COMPILER }
    end.flatten
  end


  # Comments on pretend records
  
  def concept_note_reviewer_comments
    pretend_record_comments(Loader::Batch::Review::Role::NAME_REVIEWER, 'concept-note')
  end

  def concept_note_reviewer_comments?
    concept_note_reviewer_comments.size > 0
  end

  def distribution_reviewer_comments
    pretend_record_comments(Loader::Batch::Review::Role::NAME_REVIEWER, 'distribution')
  end

  def distribution_reviewer_comments?
    distribution_reviewer_comments.size > 0
  end

  def concept_note_compiler_comments
    pretend_record_comments(Loader::Batch::Review::Role::COMPILER, 'concept-note')
  end

  def concept_note_compiler_comments?
    concept_note_compiler_comments.size > 0
  end

  def distribution_compiler_comments
    pretend_record_comments(Loader::Batch::Review::Role::COMPILER, 'distribution')
  end

  def distribution_compiler_comments?
    distribution_compiler_comments.size > 0
  end

  def pretend_record_comments(role, context)
    name_review_comments
      .includes(batch_reviewer: [:batch_review_role])
      .select { |comment| comment.reviewer.role.name == role }
      .select { |comment| comment.context == context }
  end
end
