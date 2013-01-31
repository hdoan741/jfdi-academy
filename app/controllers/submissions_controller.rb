class SubmissionsController < ApplicationController
  load_and_authorize_resource :course
  load_and_authorize_resource :mission, through: :course
  load_and_authorize_resource :submission, through: :mission

  skip_load_and_authorize_resource :submission, only: :listall
  skip_load_and_authorize_resource :mission, only: :listall

  before_filter :load_general_course_data, only: [:index, :listall, :show, :new, :create]

  def listall
    @unseen = []
    @sbms = @course.submissions.accessible_by(current_ability) +
            @course.training_submissions.accessible_by(current_ability) +
            @course.quiz_submissions.accessible_by(current_ability)

    if curr_user_course.id
      @seen = curr_user_course.get_seen_sbms
      @unseen = @sbms - @seen
      @unseen.each do |sbm|
        curr_user_course.mark_as_seen(sbm)
      end
    end
    @sbms = @sbms.sort_by(&:created_at).reverse
  end

  def show
    @qadata = {}

    if params[:grading_id]
      @grading = SubmissionGrading.find(grading_id)
    else
      @grading = @submission.final_grading
    end

    @mission.questions.each do |q|
      @qadata[q.id] = { q: q }
    end

    @submission.std_answers.each do |sa|
      @qadata[sa.question.id][:a] = sa
    end

    if @grading
      @grading.answer_gradings.each do |ag|
        @qadata[ag.student_answer.question_id][:g] = ag
      end
    end

    puts @qadata

    respond_to do |format|
      format.html { render "submissions/show_question" }
    end
  end

  def new
    @questions = @mission.questions
    respond_to do |format|
      format.html
    end
  end

  def create
    @submission.std_course = curr_user_course
    params[:answers].each do |qid, ans|
      @wq = Question.find(qid)
      sa = @submission.std_answers.build({
        text: ans,
      })
      sa.question = @wq
    end
    if @submission.save
      Activity.attempted_asm(curr_user_course, @mission)
      respond_to do |format|
        format.html
      end
    else
      respond_to do |format|
        format.html { render action: "new" }
      end
    end
  end
end
