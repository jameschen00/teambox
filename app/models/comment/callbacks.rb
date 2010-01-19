class Comment

  def before_create
    self.target ||= project

    set_status_and_assigned if self.target.is_a?(Task)
  end

  def after_create
    self.target.reload
    
    set_last_comment unless target.is_a?(User)

    @activity = project.log_activity(self,'create')

    target.after_comment(self)      if target.respond_to?(:after_comment)
    target.notify_new_comment(self) if target.respond_to?(:notify_new_comment)
    target.add_watchers(@mentioned) if target.respond_to?(:add_watchers)
  end
  
  def after_destroy
    Activity.destroy_all :target_type => self.class.to_s, :target_id => self.id

    if target
      original_id = target.last_comment_id  
      
      last_comment = Comment.find(:first, :conditions => {
        :target_type => target.class.name,
        :target_id => target.id},
        :order => 'id DESC')

      target.last_comment_id = last_comment.try(:id)
      target.save(false)
    end
  end
  
  protected

    def set_status_and_assigned
      self.previous_status      = target.previous_status
      self.assigned             = target.assigned
      self.previous_assigned_id = target.previous_assigned_id
    end
    
    def set_last_comment
      target.last_comment_id = id
      target.save(false)
    
      project.last_comment_id = id
      project.save(false)  
    end
end