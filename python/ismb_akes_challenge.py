from dreamtools.dream8.D8C1 import scoring

CHALLENGE_NAME = "DREAM ISMB AKES challenge"
CHALLENGE_SYN_ID = "syn3375314"

ADMIN_USER_IDS = [1421212]

evaluation_queues = [
    {"name":"SC1B for Network Insilico",
     "id":'3910084'},
    {"name":"SC2B for Prediction Insilico",
     "id":'4013814'}]

evaluation_queue_by_id = {q['id']:q for q in evaluation_queues}


LEADERBOARD_COLUMNS_SC1B = [
    {'column_name':'objectId',          'display_name':'objectId','type':str},
    {'column_name':'userId',            'display_name':'userId',  'type':str, 'renderer':'userid'},
    {'column_name':'entityId',          'display_name':'entityId','type':str, 'renderer':'synapseid'},
    {'column_name':'versionNumber',     'display_name':'versionNumber','type':int},
    {'column_name':'name',              'display_name':'name',    'type':str},
    {'column_name':'team',              'display_name':'team',    'type':str},
    {'column_name':'auc',               'display_name':'auc',     'type':float}]

LEADERBOARD_COLUMNS_SC2B = [
    {'column_name':'objectId',          'display_name':'objectId','type':str},
    {'column_name':'userId',            'display_name':'userId',  'type':str, 'renderer':'userid'},
    {'column_name':'entityId',          'display_name':'entityId','type':str, 'renderer':'synapseid'},
    {'column_name':'versionNumber',     'display_name':'versionNumber','type':int},
    {'column_name':'name',              'display_name':'name',    'type':str},
    {'column_name':'team',              'display_name':'team',    'type':str},
    {'column_name':'rmse',              'display_name':'rmse',    'type':float}]

leaderboard_columns = {
    '3910084':LEADERBOARD_COLUMNS_SC1B,
    '4013814':LEADERBOARD_COLUMNS_SC2B
}


def score_sc1b(pathToSubmissionFile):
    sc1b = scoring.HPNScoringNetworkInsilico(pathToSubmissionFile)
    sc1b.compute_score()
    return ({'auc':sc1b.auc}, "Scoring executed successfully")

def score_sc2b(pathToSubmissionFile):
    sc2b = scoring.HPNScoringPredictionInsilico(pathToSubmissionFile)
    sc2b.compute_all_rmse()
    return ({'rmse': sc2b.get_mean_rmse()}, "Scoring executed successfully")

def score_submission(evaluation, submission):
    """dispatch submission to the proper scoring function"""
    if evaluation.id == "3910084":
        return score_sc1b(submission.filePath)
    elif evaluation.id == "4013814":
        return score_sc2b(submission.filePath)
    else:
        raise ValueError("Unrecognized evaluation %s, %s" % (evaluation.id, evaluation.name))

