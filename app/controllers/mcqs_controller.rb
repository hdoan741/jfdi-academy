class McqsController < ApplicationController
  load_and_authorize_resource :course
  load_and_authorize_resource :assignment, through: :course
  load_and_authorize_resource :mcq, through: :assignment

  def new
    @mcq.max_grade = 1
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @mcq }
    end
  end

  def create
    @mcq.creator = current_user
    # update max grade of the assignment it belongs to
    respond_to do |format|
      if @mcq.save
        @assignment.max_grade += @mcq.max_grade
        @assignment.save
        format.html { redirect_to course_assignment_url(@course, @assignment),
                      notice: 'Question successfully added.' }
        format.json { render json: @mcq, status: :created, location: @mcq }
      else
        format.html { render action: "new" }
        format.json { render json: @mcq.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    updated = @mcq.update_attributes(params[:mcq])
    params[:answers].each do |answer|
      answer['is_correct'] = answer.has_key?('is_correct')
      if answer.has_key?('id')
        ans = Answer.find(answer['id'])
        # TODO: check if this answer does belong to the current question
        updated = updated && ans.update_attributes(answer)
      else
        ans = @mcq.answers.build(answer)
        updated = updated && ans.save
      end
    end

    respond_to do |format|
      if updated
        @mcq.assignment.update_grade
        format.html { redirect_to course_assignment_url(@course, @assignment),
                      notice: 'Assignment was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @mcq.errors, status: :unprocessable_entity }
      end
    end
  end

  def show
  end
end
