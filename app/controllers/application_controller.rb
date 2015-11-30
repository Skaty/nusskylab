# ApplicationController: base controller for Skylab
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def authenticate_user(login_required = true, admin_only = false,
                        allowed_users = [], **options)
    logged_in_user = current_user
    if !login_required
      return true
    elsif login_required && !logged_in_user
      redirect_user(options) and return false
    end
    if admin_only && !current_user_admin?
      redirect_user(options) and return false
    end
    return true if current_user_admin?
    unless allowed_users.index { |user| user.id == current_user.id }
      redirect_user(options) and return false
    end
    true
  end

  def redirect_user(options)
    redirect_path = options[:redirect_path] || home_path
    redirect_message = options[:redirect_message] ||
                       t('application.not_enough_privilege_message')
    redirect_to redirect_path, flash: { danger: redirect_message }
  end

  # TODO: remove this method later if confirmed not in use
  # Deprecated, used for check_access
  def check_access(login_required = true, admin_only = false,
                   special_access_strategy = nil)
    if login_required && current_user.nil?
      redirect_user({}) and return false
    end
    if admin_only && !current_user_admin?
      redirect_user({}) and return false
    end
    return true if current_user_admin?
    if special_access_strategy.nil?
      return true
    else
      if !special_access_strategy.call
        redirect_user({}) and return false
      else
        return true
      end
    end
  end

  def after_sign_in_path_for(_resource)
    return root_path if current_user.nil?
    student = Student.student?(current_user.id)
    adviser = Adviser.adviser?(current_user.id)
    mentor = Mentor.mentor?(current_user.id)
    admin = Admin.admin?(current_user.id)
    if student && adviser.nil? && mentor.nil? && admin.nil?
      student_path(student.id)
    elsif student.nil? && adviser && mentor.nil? && admin.nil?
      adviser_path(adviser.id)
    elsif student.nil? && adviser.nil? && mentor && admin.nil?
      mentor_path(mentor.id)
    elsif student.nil? && adviser.nil? && mentor.nil? && admin
      admin_path(admin.id)
    else
      user_path(current_user.id)
    end
  end

  def current_user_student?
    Student.student?(current_user.id) if current_user
  end

  def current_user_adviser?
    Adviser.adviser?(current_user.id) if current_user
  end

  def current_user_mentor?
    Mentor.mentor?(current_user.id) if current_user
  end

  def current_user_admin?
    Admin.admin?(current_user.id) if current_user
  end

  def page_title
    @page_title ||= 'Orbital'
  end

  def home_path
    current_user ? after_sign_in_path_for(current_user) : root_path
  end

  def record_not_found
    respond_to do |f|
      f.html { render file: "#{Rails.root}/public/404.html", status: 404 }
    end
  end

  helper_method :home_path
  helper_method :page_title
  helper_method :current_user_admin?
  helper_method :current_user_adviser?
  helper_method :current_user_mentor?
  helper_method :current_user_student?
end
