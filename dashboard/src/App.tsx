import React from 'react';
import './App.css';
import Portal from './components/home/portal/portal';
import { BrowserRouter, Switch, Route } from 'react-router-dom';
import Signup from './components/authentication/signup/signup';
import Login from './components/authentication/login/login';
import Navbar from './components/common/navbar/navbar';
import SignedInLinks from './components/common/navbar/signedInLinks';
import SignedOutLinks from './components/common/navbar/signedOutLinks';
import ResetPassword from './components/authentication/login/resetPassword';
import ForgotPassword from './components/authentication/login/forgotPassword';

function App() {
  const checkIsLoggedIn = () => {
    // TODO - logic to return boolean whether user is logged in or not
    return false;
  }

  return (
    <BrowserRouter>
      <div className="App">
        {checkIsLoggedIn() === true ?
        (<Navbar brand={SignedInLinks.brand} links={SignedInLinks.links} />) :
        (<Navbar brand={SignedOutLinks.brand} links={SignedOutLinks.links} />)}
        <Switch>
          <Route exact path='/' component={Portal} />
          <Route path='/signup' component={Signup} />
          <Route path='/login' component={Login}/>
          <Route path='/forgotpassword' component={ForgotPassword}/>
          <Route path='/passwordreset' component={ResetPassword}/>
        </Switch>
      </div>
    </BrowserRouter>
  );
}

export default App;
