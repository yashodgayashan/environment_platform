import React, { useState, useEffect } from 'react';
import { FormattedMessage } from 'react-intl';
import TextField from '@material-ui/core/TextField';
import { createStyles, makeStyles, Theme } from '@material-ui/core/styles';
import Card from '@material-ui/core/Card';
import CardContent from '@material-ui/core/CardContent';
import CardActions from '@material-ui/core/CardActions';
import Button from '@material-ui/core/Button';
import CardHeader from '@material-ui/core/CardHeader';
import Footer from '../../common/footer/footer';

const useStyles = makeStyles((theme: Theme) =>
  createStyles({
    container: {
      display: 'flex',
      flexWrap: 'wrap',
      width: 400,
      margin: `${theme.spacing(0)} auto`
    },
    submitBtn: {
      marginTop: theme.spacing(2),
      flexGrow: 1,
      background: '#24292e',
      color: '#fff'
    },
    header: {
      textAlign: 'center',
      background: '#24292e',
      color: '#fff'
    },
    card: {
      marginTop: theme.spacing(10)
    }

  }),
);

const ResetPassword = () => {
  const classes = useStyles();
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [isButtonDisabled, setIsButtonDisabled] = useState(true);
  const [helperText, setHelperText] = useState('');
  const [error, setError] = useState(false);

  useEffect(() => {
    if (password.trim()) {
      setIsButtonDisabled(false);
    } else {
      setIsButtonDisabled(true);
    }
  }, [password]);

  const handleResetPassword = () => {
    // TODO - Handle validation
    if (password === 'admin' && confirmPassword === 'admin') {
      setError(false);
      setHelperText('The password has been changed');
    } else {
      setError(true);
      setHelperText('The passwords do not match');
    }
  };

  const handleKeyPress = (e:any) => {
    if (e.keyCode === 13 || e.which === 13) {
      isButtonDisabled || handleResetPassword();
    }
  };

  return (
    <>
      <React.Fragment>
        <form className={classes.container} noValidate autoComplete="off">
          <Card className={classes.card}>
            <CardHeader className={classes.header} title="Reset Password" />
            <CardContent>
              <div>
                <FormattedMessage
                            id='Reset.Password.Label'
                            defaultMessage='Enter the new password'
                />
                <TextField
                  error={error}
                  fullWidth
                  id="Password"
                  type="password"
                  label="New Password"
                  placeholder="New Password"
                  margin="normal"
                  onChange={(e)=>setPassword(e.target.value)}
                  onKeyPress={(e)=>handleKeyPress(e)}
                />
                <TextField
                  error={error}
                  fullWidth
                  id="ConfirmPassword"
                  type="password"
                  label="Confirm New Password"
                  placeholder="Confirm New Password"
                  margin="normal"
                  onChange={(e)=>setConfirmPassword(e.target.value)}
                  onKeyPress={(e)=>handleKeyPress(e)}
                  helperText={helperText}
                />
              </div>
            </CardContent>
            <CardActions>
              <Button
                variant="contained"
                size="large"
                className={classes.submitBtn}
                onClick={()=>handleResetPassword()}
                disabled={isButtonDisabled}>
                Change Password
              </Button>
            </CardActions>
          </Card>
        </form>
        <Footer />
      </React.Fragment>
    </>
  );
}

export default ResetPassword;
